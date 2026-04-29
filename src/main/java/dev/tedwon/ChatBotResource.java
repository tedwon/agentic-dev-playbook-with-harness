package dev.tedwon;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;
import org.jboss.logging.Logger;

@Path("/api/chat")
@Consumes(MediaType.APPLICATION_JSON)
@Produces(MediaType.APPLICATION_JSON)
public class ChatBotResource {

    private static final Logger LOG = Logger.getLogger(ChatBotResource.class);

    @Inject QuoteAiService quoteAiService;

    @POST
    public ChatResponse chat(ChatRequest request) {
        LOG.infof("POST /api/chat — message: %s", request.message());
        String aiResponse = quoteAiService.chat(request.message());
        LOG.infof("AI response generated (%d chars)", aiResponse.length());
        return new ChatResponse(aiResponse);
    }
}
