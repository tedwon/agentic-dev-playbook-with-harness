package dev.tedwon;

import jakarta.annotation.PostConstruct;
import jakarta.enterprise.context.ApplicationScoped;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.concurrent.ThreadLocalRandom;
import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.jboss.logging.Logger;

@ApplicationScoped
public class QuoteService {

    private static final Logger LOG = Logger.getLogger(QuoteService.class);

    @ConfigProperty(name = "app.quote.default-category", defaultValue = "inspiration")
    String defaultCategory;

    private final List<Quote> quotes = new ArrayList<>();

    @PostConstruct
    void init() {
        quotes.add(
                new Quote(1, "Talk is cheap. Show me the code.", "Linus Torvalds", "programming"));
        quotes.add(
                new Quote(
                        2,
                        "Programs must be written for people to read.",
                        "Harold Abelson",
                        "programming"));
        quotes.add(
                new Quote(
                        3,
                        "Any fool can write code that a computer can understand.",
                        "Martin Fowler",
                        "programming"));
        quotes.add(
                new Quote(
                        4,
                        "First, solve the problem. Then, write the code.",
                        "John Johnson",
                        "programming"));
        quotes.add(
                new Quote(
                        5,
                        "The best way to predict the future is to invent it.",
                        "Alan Kay",
                        "inspiration"));
        quotes.add(
                new Quote(
                        6,
                        "Simplicity is the soul of efficiency.",
                        "Austin Freeman",
                        "inspiration"));
        quotes.add(
                new Quote(
                        7,
                        "The only way to do great work is to love what you do.",
                        "Steve Jobs",
                        "inspiration"));
        quotes.add(
                new Quote(
                        8,
                        "In the middle of difficulty lies opportunity.",
                        "Albert Einstein",
                        "inspiration"));
        LOG.infof("Initialized %d quotes (default category: %s)", quotes.size(), defaultCategory);
    }

    public List<Quote> getAllQuotes() {
        LOG.debugf("Returning all %d quotes", quotes.size());
        return List.copyOf(quotes);
    }

    public Optional<Quote> getQuoteById(long id) {
        LOG.debugf("Looking up quote by id: %d", id);
        return quotes.stream().filter(q -> q.id() == id).findFirst();
    }

    public Quote getRandomQuote() {
        int index = ThreadLocalRandom.current().nextInt(quotes.size());
        Quote quote = quotes.get(index);
        LOG.infof("Random quote selected: #%d by %s", quote.id(), quote.author());
        return quote;
    }

    public List<Quote> getQuotesByCategory(String category) {
        LOG.debugf("Filtering quotes by category: %s", category);
        return quotes.stream().filter(q -> q.category().equalsIgnoreCase(category)).toList();
    }
}
