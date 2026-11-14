package clickhouse

import (
	"context"
	"fmt"

	"github.com/ClickHouse/clickhouse-go/v2"
	"github.com/ClickHouse/clickhouse-go/v2/lib/driver"
)

type Client struct {
	Conn clickhouse.Conn
}

func NewClient(ctx context.Context, addr, db, user, pass string) (*Client, error) {
	conn, err := clickhouse.Open(&clickhouse.Options{
		Addr: []string{addr},
		Auth: clickhouse.Auth{
			Database: db,
			Username: user,
			Password: pass,
		},
		MaxOpenConns: 20,
		MaxIdleConns: 10,
	})
	if err != nil {
		return nil, fmt.Errorf("failed to configure clickhouse connection: %w", err)
	}

	if err := conn.Ping(ctx); err != nil {
		return nil, fmt.Errorf("failed to ping clickhouse: %w", err)
	}

	return &Client{Conn: conn}, nil
}

func (c *Client) Exec(ctx context.Context, sql string, params ...any) error {
	return c.Conn.Exec(ctx, sql, params...)
}

func (c *Client) Query(ctx context.Context, sql string, params ...any) ([]map[string]any, error) {
	rows, err := c.Conn.Query(ctx, sql, params...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var result []map[string]any
	cols := rows.Columns()

	for rows.Next() {
		values := make([]any, len(cols))
		ptrs := make([]any, len(cols))
		for i := range values {
			ptrs[i] = &values[i]
		}
		if err := rows.Scan(ptrs...); err != nil {
			return nil, err
		}
		rowMap := make(map[string]any)
		for i, col := range cols {
			rowMap[col] = values[i]
		}
		result = append(result, rowMap)
	}

	if err := rows.Err(); err != nil {
		return nil, err
	}

	return result, nil
}

func (c *Client) NewBatch(ctx context.Context, query string) (driver.Batch, error) {
	return c.Conn.PrepareBatch(ctx, query)
}
