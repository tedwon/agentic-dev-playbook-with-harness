package dev.tedwon;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.notNullValue;

import io.quarkus.test.junit.QuarkusIntegrationTest;
import org.junit.jupiter.api.Test;

@QuarkusIntegrationTest
class ChatBotResourceIT {

    @Test
    void testChatEndpointReturnsResponse() {
        given().contentType("application/json")
                .body("{\"message\": \"Explain the Linus Torvalds quote\"}")
                .when()
                .post("/api/chat")
                .then()
                .statusCode(200)
                .body("response", notNullValue());
    }
}
