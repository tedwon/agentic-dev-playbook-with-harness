package dev.tedwon;

import dev.langchain4j.service.SystemMessage;
import dev.langchain4j.service.UserMessage;
import io.quarkiverse.langchain4j.RegisterAiService;
import jakarta.enterprise.context.ApplicationScoped;

@RegisterAiService
@ApplicationScoped
public interface QuoteChatService {

    @SystemMessage(
            """
            당신은 친절한 명언 전문가입니다. 반드시 한국어로 답변하세요. 명언을 추천할 때는 왜 그 명언이 적절한지 간단히 설명하세요. 간결하게 2-3문장으로 답변하세요.

            Known quotes:
            {quotes}
            """)
    @UserMessage("{message}")
    String chat(String message, String quotes);
}
