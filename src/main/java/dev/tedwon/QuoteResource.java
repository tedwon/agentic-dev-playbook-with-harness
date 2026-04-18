package dev.tedwon;

import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.PathParam;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;
import java.util.List;
import org.jboss.logging.Logger;

@Path("/api/quotes")
@Produces(MediaType.APPLICATION_JSON)
public class QuoteResource {

    private static final Logger LOG = Logger.getLogger(QuoteResource.class);

    @Inject QuoteService quoteService;

    @GET
    public List<Quote> getAllQuotes(@QueryParam("category") String category) {
        if (category != null && !category.isBlank()) {
            LOG.infof("GET /api/quotes?category=%s", category);
            return quoteService.getQuotesByCategory(category);
        }
        LOG.info("GET /api/quotes");
        return quoteService.getAllQuotes();
    }

    @GET
    @Path("/random")
    public Quote getRandomQuote() {
        LOG.info("GET /api/quotes/random");
        return quoteService.getRandomQuote();
    }

    @GET
    @Path("/{id}")
    public Response getQuoteById(@PathParam("id") long id) {
        LOG.infof("GET /api/quotes/%d", id);
        return quoteService
                .getQuoteById(id)
                .map(quote -> Response.ok(quote).build())
                .orElseGet(() -> Response.status(Response.Status.NOT_FOUND).build());
    }
}
