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

@Path("/api/quotes")
@Produces(MediaType.APPLICATION_JSON)
public class QuoteResource {

    @Inject
    QuoteService quoteService;

    @GET
    public List<Quote> getAllQuotes(@QueryParam("category") String category) {
        System.out.println("Getting all quotes");
        if (category != null && !category.isBlank()) {
            return quoteService.getQuotesByCategory(category);
        }
        return quoteService.getAllQuotes();
    }

    @GET
    @Path("/random")
    public Quote getRandomQuote() {
      System.out.println("Getting random quote");
      return quoteService.getRandomQuote();
    }

    @GET
    @Path("/{id}")
    public Response getQuoteById(@PathParam("id") long id) {
        return quoteService.getQuoteById(id)
                .map(quote -> Response.ok(quote).build())
                .orElseGet(() -> Response.status(Response.Status.NOT_FOUND).build());
    }
}
