package com.taskmanager.service;

import com.taskmanager.dto.TaskRequest;
import com.taskmanager.dto.TaskResponse;
import com.taskmanager.entity.Task;
import com.taskmanager.entity.TaskStatus;
import com.taskmanager.entity.User;
import com.taskmanager.repository.TaskRepository;
import com.taskmanager.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class TaskService {

    private final TaskRepository taskRepository;
    private final UserRepository userRepository;

    @Transactional(readOnly = true)
    public List<TaskResponse> getTasksByUser(Long userId, String status, String search) {
        String normalizedSearch = (search == null || search.isBlank()) ? null : search.trim();
        return taskRepository.searchTasks(userId, parseStatusFilter(status), normalizedSearch)
                .stream()
                .map(TaskResponse::from)
                .toList();
    }

    @Transactional(readOnly = true)
    public TaskResponse getTaskByUser(Long userId, Long taskId) {
        return TaskResponse.from(findOwnedTask(userId, taskId));
    }

    @Transactional
    public TaskResponse createTask(Long userId, TaskRequest request) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        Task task = new Task();
        task.setTitle(request.title().trim());
        task.setDescription(normalize(request.description()));
        task.setStatus(parseStatus(request.status()));
        task.setUser(user);

        return TaskResponse.from(taskRepository.save(task));
    }

    @Transactional
    public TaskResponse updateTask(Long userId, Long taskId, TaskRequest request) {
        Task task = findOwnedTask(userId, taskId);

        if (request.title() != null && !request.title().isBlank()) {
            task.setTitle(request.title().trim());
        }
        if (request.description() != null) {
            task.setDescription(normalize(request.description()));
        }
        if (request.status() != null && !request.status().isBlank()) {
            task.setStatus(parseStatus(request.status()));
        }

        return TaskResponse.from(taskRepository.save(task));
    }

    @Transactional
    public void deleteTask(Long userId, Long taskId) {
        taskRepository.delete(findOwnedTask(userId, taskId));
    }

    private Task findOwnedTask(Long userId, Long taskId) {
        Task task = taskRepository.findById(taskId)
                .orElseThrow(() -> new IllegalArgumentException("Task not found"));
        if (!task.getUser().getId().equals(userId)) {
            throw new AccessDeniedException("You do not have access to this task");
        }
        return task;
    }

    private TaskStatus parseStatusFilter(String statusValue) {
        if (statusValue == null || statusValue.isBlank()) {
            return null;
        }
        return parseStatus(statusValue);
    }

    private TaskStatus parseStatus(String statusValue) {
        if (statusValue == null || statusValue.isBlank()) {
            return TaskStatus.TODO;
        }
        try {
            return TaskStatus.valueOf(statusValue.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid status: " + statusValue
                    + ". Allowed values: TODO, IN_PROGRESS, DONE");
        }
    }

    private String normalize(String description) {
        return description == null || description.isBlank() ? null : description.trim();
    }
}