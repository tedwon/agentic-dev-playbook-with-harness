package dev.tedwon;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.Matchers.greaterThan;
import static org.hamcrest.Matchers.hasKey;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

@QuarkusTest
class QuoteResourceTest {

    @Test
    void testGetAllQuotes() {
        given().when().get("/api/quotes").then().statusCode(200).body("size()", greaterThan(0));
    }

    @Test
    void testGetRandomQuote() {
        given().when()
                .get("/api/quotes/random")
                .then()
                .statusCode(200)
                .body("$", hasKey("id"))
                .body("$", hasKey("text"))
                .body("$", hasKey("author"));
    }

    @Test
    void testGetQuoteById() {
        given().when()
                .get("/api/quotes/1")
                .then()
                .statusCode(200)
                .body("author", is("Linus Torvalds"));
    }

    @Test
    void testGetQuoteByIdNotFound() {
        given().when().get("/api/quotes/999").then().statusCode(404);
    }

    @Test
    void testGetQuotesByCategory() {
        given().when()
                .get("/api/quotes?category=programming")
                .then()
                .statusCode(200)
                .body("size()", greaterThan(0))
                .body("[0].category", is("programming"));
    }
}
