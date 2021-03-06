package com.kdp.golf.websocket;

import com.kdp.golf.game.GameController;
import com.kdp.golf.user.UserController;
import com.kdp.golf.websocket.message.CreateGameMessage;
import com.kdp.golf.websocket.message.Message;
import com.kdp.golf.websocket.message.MessageDecoder;
import com.kdp.golf.websocket.message.StartGameMessage;
import com.kdp.golf.websocket.response.Response;
import com.kdp.golf.websocket.response.ResponseEncoder;
import org.jboss.logging.Logger;

import javax.enterprise.context.ApplicationScoped;
import javax.websocket.*;
import javax.websocket.server.ServerEndpoint;
import java.util.Collection;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@ApplicationScoped
@ServerEndpoint(
        value = "/ws",
        decoders = MessageDecoder.class,
        encoders = ResponseEncoder.class
)
public class WebSocket {

    private final Map<String, Session> sessions;
    private final UserController userController;
    private final GameController gameController;
    private final Logger log = Logger.getLogger(WebSocket.class);

    public WebSocket(UserController userController, GameController gameController) {
        sessions = new ConcurrentHashMap<>();
        this.userController = userController;
        this.gameController = gameController;
    }

    @OnOpen
    public void onOpen(Session session) {
        log.info("websocket connected: " + session.getId());
        sessions.put(session.getId(), session);
        userController.loginAnonymous(session);
    }

    @OnClose
    public void onClose(Session session) {
        log.info("websocket closed: " + session.getId());
        sessions.remove(session.getId());
        userController.sessionClosed(session);
    }

    @OnMessage
    public void onMessage(Session session, Message message) {
        log.info("message received: " + message);

        if (message instanceof CreateGameMessage) {
            gameController.createGame(session);
        } else if (message instanceof StartGameMessage s) {
            gameController.startGame(session, s.gameId());
        }
    }

    @OnError
    public void onError(Session session, Throwable throwable) {
        log.error("websocket error", throwable);
    }

    public void sendToSession(Session session, Response response) {
        session.getAsyncRemote()
                .sendObject(response, result -> {
                    if (result.getException() != null) {
                        log.error("error sending to " + session.getId() + ": " + result.getException());
                    }
                });
    }

    public void sendToSessionIds(Collection<String> sessionIds, Response response) {
        sessionIds.forEach(id -> sendToSession(sessions.get(id), response));
    }

    public void broadcast(Response response) {
        sessions.values()
                .forEach(s -> sendToSession(s, response));
    }
}
