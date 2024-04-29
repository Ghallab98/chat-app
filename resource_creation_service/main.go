package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strconv"

	"github.com/go-redis/redis/v8"
)

type Chat struct {
    ApplicationToken string `json:"application_token"`
    Number       int64  `json:"number"`
}

type Message struct {
    ApplicationToken string `json:"application_token"`
    ChatNumber       int   `json:"chat_number"`
    Number    int64  `json:"number"`
    Body             string `json:"body"`
}

func main() {
    rdb := redis.NewClient(&redis.Options{
        Addr:     os.Getenv("REDIS_HOST") + ":" + os.Getenv("REDIS_PORT"),
        Password: "",
        DB:       0,
    })

    http.HandleFunc("/create-chat", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
            return
        }

        var chat Chat
        err := json.NewDecoder(r.Body).Decode(&chat)
        if err != nil {
            http.Error(w, "Failed to parse chat data", http.StatusBadRequest)
            return
        }

        // Get the context from the incoming request
        ctx := r.Context()

        // Increment chats_count in Redis hash using application_token as key
        chatNumber, err := rdb.HIncrBy(ctx, "applications", chat.ApplicationToken, 1).Result()
        if err != nil {
            http.Error(w, "Failed to increment chat number", http.StatusInternalServerError)
            return
        }

        // Set the ChatNumber field of the chat struct
        chat.Number = chatNumber

        // Convert the chat struct into a JSON string
        chatJSON, err := json.Marshal(chat)
        if err != nil {
            http.Error(w, "Failed to convert chat data into JSON", http.StatusInternalServerError)
            return
        }

        // Enqueue chat data into Redis queue
        _, err = rdb.LPush(ctx, "chats_creation", chatJSON).Result()
        // log chat data and the Result of the LPUSH operation
        if err != nil {
            http.Error(w, "Failed to enqueue chat data", http.StatusInternalServerError)
            return
        }
    
        // Respond with success and chat_number
        w.WriteHeader(http.StatusCreated)
        w.Write([]byte(strconv.FormatInt(chatNumber, 10)))
    })

    // Define HTTP handler function to handle message creation requests
    http.HandleFunc("/create-message", func(w http.ResponseWriter, r *http.Request) {
        if r.Method != http.MethodPost {
            http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
            return
        }
    
        var message Message
        err := json.NewDecoder(r.Body).Decode(&message)
        if err != nil {
            http.Error(w, "Failed to parse message data", http.StatusBadRequest)
            return
        }

        // Get the context from the incoming request
        ctx := r.Context()

        // Create a key from application_token and chat_number
        key := fmt.Sprintf("%s,%d", message.ApplicationToken, message.ChatNumber)
        // Increment messages_count in Redis hash using the key
        messageNumber, err := rdb.HIncrBy(ctx, "chats", key, 1).Result()
        if err != nil {
            http.Error(w, "Failed to increment message number", http.StatusInternalServerError)
            return
        }

        // Set the MessageNumber field of the message struct
        message.Number = messageNumber

        // Convert the message struct into a JSON string
        messageJSON, err := json.Marshal(message)
        if err != nil {
            http.Error(w, "Failed to convert message data into JSON", http.StatusInternalServerError)
            return
        }
    
        // Enqueue message data into Redis queue
        _, err = rdb.LPush(ctx, "messages_creation", messageJSON).Result()
        if err != nil {
            http.Error(w, "Failed to enqueue message data", http.StatusInternalServerError)
            return
        }
    
        // Respond with success and message_number
        w.WriteHeader(http.StatusCreated)
        w.Write([]byte(strconv.FormatInt(messageNumber, 10)))
    })

    // Start HTTP server
    log.Println("Starting Go server on port :8080")
    http.ListenAndServe(":8080", nil)
}
