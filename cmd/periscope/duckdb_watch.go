package main

import (
	"context"
	"fmt"

	"github.com/latentsignal-org/periscope/internal/config"
	duckdbsync "github.com/latentsignal-org/periscope/internal/duckdb"
)

// duckDBPusher runs a local sync then pushes to DuckDB. The watch loop keeps
// one pusher for its lifetime so sync and push share the same sync engine
// state as the unwatched-root poller.
type duckDBPusher struct {
	localSync  func(context.Context) error
	pushMirror func(
		context.Context, DuckDBPushConfig, bool,
	) (duckdbsync.PushResult, error)
}

func (p *duckDBPusher) push(
	ctx context.Context, reason pushReason, full bool, cfg DuckDBPushConfig,
) error {
	if err := p.localSync(ctx); err != nil {
		return fmt.Errorf("local sync: %w", err)
	}
	if err := ctx.Err(); err != nil {
		return err
	}
	res, err := p.pushMirror(ctx, cfg, full)
	if err != nil {
		return err
	}
	return completeDuckDBWatchPush(res, reason)
}

func (b *localArchiveWriteBackend) newDuckDBPusher(
	localSync func(context.Context) error,
	duckCfg config.DuckDBConfig,
	projects, exclude []string,
) *duckDBPusher {
	return &duckDBPusher{
		localSync: localSync,
		pushMirror: func(
			ctx context.Context, cfg DuckDBPushConfig, forceFull bool,
		) (duckdbsync.PushResult, error) {
			return b.pushDuckDBMirror(
				ctx, duckCfg, cfg, projects, exclude, forceFull,
			)
		},
	}
}

func (b *localArchiveWriteBackend) pushDuckDBMirror(
	ctx context.Context,
	duckCfg config.DuckDBConfig,
	cfg DuckDBPushConfig,
	projects, excludeProjects []string,
	forceFull bool,
) (duckdbsync.PushResult, error) {
	if err := duckdbsync.ValidatePushTarget(duckCfg); err != nil {
		return duckdbsync.PushResult{}, err
	}
	opts := duckdbsync.SyncOptions{
		Projects:        projects,
		ExcludeProjects: excludeProjects,
		Automatic:       cfg.Automatic,
	}
	return duckdbsync.Push(
		ctx, duckCfg.Path, b.database, duckCfg.MachineName, opts, forceFull, nil,
	)
}
