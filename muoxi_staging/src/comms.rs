use crate::connstates::{AwaitingAcctName, ConnState};
use futures::SinkExt;
use std::collections::{HashMap, HashSet};
use std::net::SocketAddr;
use std::pin::Pin;
use std::sync::Arc;
use std::task::{Context, Poll};
use tokio::net::TcpStream;
use tokio::stream::{Stream, StreamExt};
use tokio::sync::{mpsc, Mutex};
use tokio_util::codec::{Framed, LinesCodec, LinesCodecError};

pub type UID = usize;
type Tx = mpsc::UnboundedSender<String>;
type Rx = mpsc::UnboundedReceiver<String>;

#[derive(Debug)]
pub enum Message {
    FromClient(String),
    OnRx(String),
}

#[derive(Debug)]
pub struct ClientAccount {
    pub name: String,
    pub ncharacters: u32,
}

impl ClientAccount {
    pub fn new(name: String) -> Self {
        Self {
            name: name,
            ncharacters: 0,
        }
    }
}

#[derive(Debug)]
pub struct Client {
    pub uid: UID,
    pub state: ConnState,
    pub lines: Framed<TcpStream, LinesCodec>,
    pub addr: SocketAddr,
    rx: Rx,
}

impl Client {
    pub async fn new(
        uid: UID,
        server: Arc<Mutex<Server>>,
        stream: TcpStream,
    ) -> tokio::io::Result<Self> {
        let addr = stream.peer_addr()?;
        let (tx, rx) = mpsc::unbounded_channel();
        let comms = Comms(addr, tx);
        server.lock().await.clients.insert(uid, comms);
        Ok(Self {
            uid: uid,
            state: ConnState::AwaitingAcctName(AwaitingAcctName::new()),
            lines: Framed::new(stream, LinesCodec::new()),
            addr: addr,
            rx: rx,
        })
    }
}

impl Stream for Client {
    type Item = Result<Message, LinesCodecError>;

    fn poll_next(mut self: Pin<&mut Self>, cx: &mut Context<'_>) -> Poll<Option<Self::Item>> {
        if let Poll::Ready(Some(v)) = Pin::new(&mut self.rx).poll_next(cx) {
            return Poll::Ready(Some(Ok(Message::OnRx(v))));
        }

        let result: Option<_> = futures::ready!(Pin::new(&mut self.lines).poll_next(cx));

        Poll::Ready(match result {
            Some(Ok(message)) => Some(Ok(Message::FromClient(message))),
            Some(Err(e)) => Some(Err(e)),
            None => None,
        })
    }
}

#[derive(Debug)]
pub struct Comms(pub SocketAddr, pub Tx);

#[derive(Debug)]
pub struct Server {
    pub clients: HashMap<UID, Comms>,
    pub accounts: HashMap<UID, ClientAccount>,
}

impl Server {
    pub fn new() -> Self {
        Self {
            clients: HashMap::new(),
            accounts: HashMap::new(),
        }
    }

    pub async fn broadcast(&mut self, sender: SocketAddr, message: &str) {
        for (uid, comms) in self.clients.iter_mut() {
            if comms.0 != sender {
                let _ = comms.1.send(message.into());
            } else {
                let msg = format!("You broadcasted, {}", message);
                let _ = comms.1.send(msg.into());
            }
        }
    }
}