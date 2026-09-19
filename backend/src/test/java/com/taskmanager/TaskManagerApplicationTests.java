package com.taskmanager;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.MvcResult;

import static org.assertj.core.api.Assertions.assertThat;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
class TaskManagerApplicationTests {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void contextLoads() {
    }

    @Test
    void fullAuthAndTaskFlow() throws Exception {
        // 1. Register
        MvcResult register = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "e2e@test.com",
                                  "fullName": "E2E User",
                                  "password": "secret123"
                                }
                                """))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andExpect(jsonPath("$.email").value("e2e@test.com"))
                .andReturn();

        String registerToken = extractToken(register);
        assertThat(registerToken).isNotBlank();

        // 2. Duplicate registration rejected
        mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "e2e@test.com",
                                  "fullName": "E2E User",
                                  "password": "secret123"
                                }
                                """))
                .andExpect(status().isBadRequest());

        // 3. Login
        MvcResult login = mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "e2e@test.com",
                                  "password": "secret123"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.token").isNotEmpty())
                .andReturn();

        String loginToken = extractToken(login);
        assertThat(loginToken).isNotBlank();

        // 4. Wrong password rejected
        mockMvc.perform(post("/api/auth/login")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "e2e@test.com",
                                  "password": "wrong-password"
                                }
                                """))
                .andExpect(status().isBadRequest());

        // 5. Request without token rejected
        mockMvc.perform(get("/api/tasks"))
                .andExpect(status().isForbidden());

        // 6. Create task A (TODO) and task B (DONE) to exercise SQL filtering
        long taskA = createTask(loginToken, "Write backend tests", "Cover auth and task CRUD", "TODO");
        long taskB = createTask(loginToken, "Grocery shopping", "Buy milk and eggs", "DONE");

        // 7. Get single task (owner) -> 200
        mockMvc.perform(get("/api/tasks/" + taskA)
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.id").value(taskA))
                .andExpect(jsonPath("$.title").value("Write backend tests"));

        // 8. List tasks (newest first)
        mockMvc.perform(get("/api/tasks").header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(2));

        // 9. Filter by status
        mockMvc.perform(get("/api/tasks")
                        .param("status", "DONE")
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].title").value("Grocery shopping"));

        // 10. Search by title (case-insensitive substring)
        mockMvc.perform(get("/api/tasks")
                        .param("search", "BACKEND")
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].title").value("Write backend tests"));

        // 11. Search matches description too
        mockMvc.perform(get("/api/tasks")
                        .param("search", "milk")
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1))
                .andExpect(jsonPath("$[0].title").value("Grocery shopping"));

        // 12. Combined status + search (single SQL query, in/out-of-db filter removed)
        mockMvc.perform(get("/api/tasks")
                        .param("status", "DONE")
                        .param("search", "backend")
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        mockMvc.perform(get("/api/tasks")
                        .param("status", "DONE")
                        .param("search", "grocery")
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));

        // 13. Invalid status -> 400
        mockMvc.perform(get("/api/tasks")
                        .param("status", "NOPE")
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isBadRequest());

        // 14. Update task (owner) -> 200
        mockMvc.perform(put("/api/tasks/" + taskA)
                        .header("Authorization", "Bearer " + loginToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "Write backend tests",
                                  "description": "Cover auth and task CRUD",
                                  "status": "DONE"
                                }
                                """))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.status").value("DONE"));

        // 15. Another user cannot read/update/delete this task -> 403
        String otherToken = registerUser("other@test.com", "Other User");
        mockMvc.perform(get("/api/tasks/" + taskA)
                        .header("Authorization", "Bearer " + otherToken))
                .andExpect(status().isForbidden());
        mockMvc.perform(put("/api/tasks/" + taskA)
                        .header("Authorization", "Bearer " + otherToken)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "hacked",
                                  "status": "DONE"
                                }
                                """))
                .andExpect(status().isForbidden());
        mockMvc.perform(delete("/api/tasks/" + taskA)
                        .header("Authorization", "Bearer " + otherToken))
                .andExpect(status().isForbidden());

        // 16. Non-existent task still 400; new user's task list is empty
        mockMvc.perform(delete("/api/tasks/9999")
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isBadRequest());
        mockMvc.perform(get("/api/tasks").header("Authorization", "Bearer " + otherToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(0));

        // 17. Owner deletes the remaining task
        mockMvc.perform(delete("/api/tasks/" + taskA)
                        .header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isNoContent());

        mockMvc.perform(get("/api/tasks").header("Authorization", "Bearer " + loginToken))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.length()").value(1));
    }

    private long createTask(String token, String title, String description, String status) throws Exception {
        MvcResult created = mockMvc.perform(post("/api/tasks")
                        .header("Authorization", "Bearer " + token)
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "title": "%s",
                                  "description": "%s",
                                  "status": "%s"
                                }
                                """.formatted(title, description, status)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.id").exists())
                .andReturn();
        return objectMapper.readTree(created.getResponse().getContentAsString()).get("id").asLong();
    }

    private String registerUser(String email, String fullName) throws Exception {
        MvcResult register = mockMvc.perform(post("/api/auth/register")
                        .contentType(MediaType.APPLICATION_JSON)
                        .content("""
                                {
                                  "email": "%s",
                                  "fullName": "%s",
                                  "password": "secret123"
                                }
                                """.formatted(email, fullName)))
                .andExpect(status().isCreated())
                .andReturn();
        return extractToken(register);
    }

    private String extractToken(MvcResult result) throws Exception {
        JsonNode node = objectMapper.readTree(result.getResponse().getContentAsString());
        return node.get("token").asText();
    }
}