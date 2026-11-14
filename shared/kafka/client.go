package kafka

import (
	"context"
	"fmt"
	"io"
	"time"

	"github.com/segmentio/kafka-go"
)

type Client struct {
	brokers []string
}

type Producer struct {
	writer *kafka.Writer
}

func NewClient(brokers []string) *Client {
	return &Client{brokers: brokers}
}

func NewProducer(brokers []string, topic string) *Producer {
	w := &kafka.Writer{
		Addr:         kafka.TCP(brokers...),
		Topic:        topic,
		Balancer:     &kafka.Hash{},
		Async:        true,
		BatchSize:    1000,
		BatchTimeout: 10 * time.Millisecond,
		Compression:  kafka.Snappy,
		RequiredAcks: kafka.RequireOne,
	}
	return &Producer{writer: w}
}

func (p *Producer) Send(ctx context.Context, key, value []byte) error {
	err := p.writer.WriteMessages(ctx, kafka.Message{
		Key:   key,
		Value: value,
	})
	if err != nil {
		return fmt.Errorf("failed to write message to kafka: %w", err)
	}
	return nil
}

func (p *Producer) Close() error {
	return p.writer.Close()
}

func (c *Client) ReadAll(ctx context.Context, topic, group string) ([]kafka.Message, error) {
	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers:     c.brokers,
		GroupID:     group,
		Topic:       topic,
		StartOffset: kafka.FirstOffset,
	})
	defer r.Close()

	var msgs []kafka.Message
	for {
		readCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
		msg, err := r.ReadMessage(readCtx)
		cancel()

		if err == context.DeadlineExceeded || err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("failed to read message: %w", err)
		}
		msgs = append(msgs, msg)
	}
	return msgs, nil
}

func (c *Client) ReadAllWithoutMark(ctx context.Context, topic, group string) ([]kafka.Message, error) {
	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers:     c.brokers,
		GroupID:     group,
		Topic:       topic,
		StartOffset: kafka.FirstOffset,
	})
	defer r.Close()

	var msgs []kafka.Message
	for {
		readCtx, cancel := context.WithTimeout(ctx, 2*time.Second)
		msg, err := r.FetchMessage(readCtx)
		cancel()

		if err == context.DeadlineExceeded || err == io.EOF {
			break
		}
		if err != nil {
			return nil, fmt.Errorf("failed to fetch message: %w", err)
		}
		msgs = append(msgs, msg)
	}
	return msgs, nil
}

func (c *Client) ListenAndExecute(ctx context.Context, topic, group string, handler func(kafka.Message) error) error {
	r := kafka.NewReader(kafka.ReaderConfig{
		Brokers:     c.brokers,
		GroupID:     group,
		Topic:       topic,
		StartOffset: kafka.FirstOffset,
		MinBytes:    10e3,
		MaxBytes:    10e6,
	})
	defer r.Close()

	for {
		msg, err := r.ReadMessage(ctx)
		if err != nil {
			if ctx.Err() != nil {
				return nil
			}
			return fmt.Errorf("kafka consumer error: %w", err)
		}

		if err := handler(msg); err != nil {
			return fmt.Errorf("handler error: %w", err)
		}
	}
}
