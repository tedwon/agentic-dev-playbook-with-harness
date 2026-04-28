package dev.tedwon;

import jakarta.inject.Inject;
import jakarta.ws.rs.Consumes;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.WebApplicationException;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import java.util.stream.Collectors;
import org.jboss.logging.Logger;

@Path("/api/chat")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class QuoteChatResource {

    private static final Logger LOG = Logger.getLogger(QuoteChatResource.class);

    @Inject QuoteChatService chatService;

    @Inject QuoteService quoteService;

    static final int MAX_MESSAGE_LENGTH = 500;

    @POST
    public ChatResponse chat(ChatRequest request) {
        if (request == null || request.message() == null || request.message().isBlank()) {
            throw new WebApplicationException("Message is required", Response.Status.BAD_REQUEST);
        }
        if (request.message().length() > MAX_MESSAGE_LENGTH) {
            throw new WebApplicationException(
                    "Message must not exceed " + MAX_MESSAGE_LENGTH + " characters",
                    Response.Status.BAD_REQUEST);
        }
        LOG.debugf("Chat request: %s", request.message());
        String quotes = formatQuotes(quoteService.getAllQuotes());
        try {
            String response = chatService.chat(request.message(), quotes);
            return new ChatResponse(response);
        } catch (Exception e) {
            LOG.errorf("LLM service call failed: %s", e.getMessage());
            throw new WebApplicationException(
                    "AI service is temporarily unavailable", Response.Status.SERVICE_UNAVAILABLE);
        }
    }

    private String formatQuotes(List<Quote> quotes) {
        return quotes.stream()
                .map(
                        q ->
                                String.format(
                                        "- \"%s\" — %s (category: %s)",
                                        q.text(), q.author(), q.category()))
                .collect(Collectors.joining("\n"));
    }
}
