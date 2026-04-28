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

    @POST
    public ChatResponse chat(ChatRequest request) {
        if (request == null || request.message() == null || request.message().isBlank()) {
            throw new WebApplicationException("Message is required", Response.Status.BAD_REQUEST);
        }
        LOG.infof("Chat request: %s", request.message());
        String quotes = formatQuotes(quoteService.getAllQuotes());
        String response = chatService.chat(request.message(), quotes);
        return new ChatResponse(response);
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
