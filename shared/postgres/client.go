package postgres

import (
	"context"
	"fmt"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

type Client struct {
	Pool *pgxpool.Pool
}

func NewClient(ctx context.Context, dsn string, maxConns int32) (*Client, error) {
	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("unable to parse dsn: %w", err)
	}

	config.MaxConns = maxConns
	config.MinConns = 2
	config.MaxConnLifetime = 30 * time.Minute
	config.MaxConnIdleTime = 15 * time.Minute

	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		return nil, fmt.Errorf("unable to create connection pool: %w", err)
	}

	if err := pool.Ping(ctx); err != nil {
		return nil, fmt.Errorf("unable to ping database: %w", err)
	}

	return &Client{Pool: pool}, nil
}

func (c *Client) Exec(ctx context.Context, sql string, params ...any) (int64, error) {
	tag, err := c.Pool.Exec(ctx, sql, params...)
	if err != nil {
		return 0, err
	}
	return tag.RowsAffected(), nil
}

func (c *Client) Query(ctx context.Context, sql string, params ...any) ([]map[string]any, error) {
	rows, err := c.Pool.Query(ctx, sql, params...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []map[string]any
	fieldDescs := rows.FieldDescriptions()

	for rows.Next() {
		values, err := rows.Values()
		if err != nil {
			return nil, err
		}
		rowMap := make(map[string]any)
		for i, fd := range fieldDescs {
			rowMap[string(fd.Name)] = values[i]
		}
		result = append(result, rowMap)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return result, nil
}

func (c *Client) Close() {
	c.Pool.Close()
}
