package redis

import (
	"context"
	"fmt"
	"time"

	"github.com/redis/go-redis/v9"
)

type Client struct {
	RDB *redis.Client
}

func NewClient(ctx context.Context, addr, password string) (*Client, error) {
	rdb := redis.NewClient(&redis.Options{
		Addr:         addr,
		Password:     password,
		PoolSize:     100,
		MinIdleConns: 20,
		ReadTimeout:  2 * time.Second,
		WriteTimeout: 2 * time.Second,
	})

	if err := rdb.Ping(ctx).Err(); err != nil {
		return nil, fmt.Errorf("failed to ping redis: %w", err)
	}

	return &Client{RDB: rdb}, nil
}

func (c *Client) Query(ctx context.Context, cmd string, args ...any) (any, error) {
	redisArgs := make([]any, 0, len(args)+1)
	redisArgs = append(redisArgs, cmd)
	redisArgs = append(redisArgs, args...)

	res, err := c.RDB.Do(ctx, redisArgs...).Result()
	if err != nil {
		if err == redis.Nil {
			return nil, nil
		}
		return nil, err
	}
	return res, nil
}

func (c *Client) Close() error {
	return c.RDB.Close()
}
