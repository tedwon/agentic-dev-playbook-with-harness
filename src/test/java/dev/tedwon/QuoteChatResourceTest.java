package dev.tedwon;

import static io.restassured.RestAssured.given;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.Matchers.emptyString;
import static org.hamcrest.Matchers.not;

import io.quarkus.test.junit.QuarkusTest;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.Test;

@QuarkusTest
class QuoteChatResourceTest {

    @Test
    void testChatEndpoint() {
        given().contentType(ContentType.JSON)
                .body("{\"message\": \"Tell me about the quote by Linus Torvalds\"}")
                .when()
                .post("/api/chat")
                .then()
                .statusCode(200)
                .body("response", notNullValue())
                .body("response", not(emptyString()));
    }

    @Test
    void testChatEndpointEmptyMessage() {
        given().contentType(ContentType.JSON)
                .body("{\"message\": \"\"}")
                .when()
                .post("/api/chat")
                .then()
                .statusCode(400);
    }
}
