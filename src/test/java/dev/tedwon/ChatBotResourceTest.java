package dev.tedwon;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.Matchers.notNullValue;

import io.quarkus.test.InjectMock;
import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

@QuarkusTest
class ChatBotResourceTest {

    @InjectMock QuoteAiService quoteAiService;

    @BeforeEach
    void setUp() {
        Mockito.when(quoteAiService.chat(Mockito.anyString()))
                .thenReturn("This is a test AI response about quotes.");
    }

    @Test
    void testChatEndpoint() {
        given().contentType("application/json")
                .body("{\"message\": \"Explain the Linus Torvalds quote\"}")
                .when()
                .post("/api/chat")
                .then()
                .statusCode(200)
                .body("response", notNullValue())
                .body("response", is("This is a test AI response about quotes."));
    }

    @Test
    void testChatEndpointWithEmptyMessage() {
        given().contentType("application/json")
                .body("{\"message\": \"\"}")
                .when()
                .post("/api/chat")
                .then()
                .statusCode(200)
                .body("response", notNullValue());
    }
}
