package com.taskmanager.config;

import com.taskmanager.entity.Task;
import com.taskmanager.entity.TaskStatus;
import com.taskmanager.entity.User;
import com.taskmanager.repository.TaskRepository;
import com.taskmanager.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.crypto.password.PasswordEncoder;

@Configuration
@RequiredArgsConstructor
public class DataInitializer {

    private static final Logger log = LoggerFactory.getLogger(DataInitializer.class);

    @Bean
    public CommandLineRunner seedUsers(UserRepository userRepository,
                                       TaskRepository taskRepository,
                                       PasswordEncoder passwordEncoder) {
        return args -> {
            if (userRepository.count() > 0) {
                return;
            }

            User demo = new User();
            demo.setEmail("demo@example.com");
            demo.setFullName("Demo User");
            demo.setPassword(passwordEncoder.encode("password123"));
            userRepository.save(demo);

            taskRepository.save(buildTask("Welcome to Task Manager", "Create your first task and start being productive.", TaskStatus.TODO, demo));
            taskRepository.save(buildTask("Learn Spring Boot", "Explore JWT authentication and Spring Data JPA.", TaskStatus.IN_PROGRESS, demo));
            taskRepository.save(buildTask("Finish the test", "Full-stack app with React, Spring Boot and Flutter.", TaskStatus.DONE, demo));

            log.info("Seeded demo user: demo@example.com / password123");
        };
    }

    private Task buildTask(String title, String description, TaskStatus status, User user) {
        Task task = new Task();
        task.setTitle(title);
        task.setDescription(description);
        task.setStatus(status);
        task.setUser(user);
        return task;
    }
}
