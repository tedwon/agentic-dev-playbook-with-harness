package dev.tedwon;

import static org.junit.jupiter.api.Assertions.*;

import io.quarkus.test.junit.QuarkusTest;
import jakarta.inject.Inject;
import java.util.List;
import java.util.Optional;
import org.junit.jupiter.api.Test;

@QuarkusTest
class QuoteServiceTest {

    @Inject QuoteService quoteService;

    @Test
    void testGetAllQuotesReturnsNonEmpty() {
        List<Quote> quotes = quoteService.getAllQuotes();
        assertFalse(quotes.isEmpty());
        assertEquals(8, quotes.size());
    }

    @Test
    void testGetRandomQuoteReturnsNonNull() {
        Quote quote = quoteService.getRandomQuote();
        assertNotNull(quote);
        assertNotNull(quote.text());
        assertNotNull(quote.author());
    }

    @Test
    void testGetQuoteByIdFound() {
        Optional<Quote> quote = quoteService.getQuoteById(1);
        assertTrue(quote.isPresent());
        assertEquals("Linus Torvalds", quote.get().author());
    }

    @Test
    void testGetQuoteByIdNotFound() {
        Optional<Quote> quote = quoteService.getQuoteById(999);
        assertTrue(quote.isEmpty());
    }

    @Test
    void testGetQuotesByCategory() {
        List<Quote> programming = quoteService.getQuotesByCategory("programming");
        assertFalse(programming.isEmpty());
        programming.forEach(q -> assertEquals("programming", q.category()));
    }
}
