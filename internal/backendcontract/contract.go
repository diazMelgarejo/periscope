// Package backendcontract centralizes compile-time checks that every storage
// backend implements the full server-facing db.Store capability surface.
package backendcontract

import (
	"github.com/latentsignal-org/periscope/internal/db"
	duckdbstore "github.com/latentsignal-org/periscope/internal/duckdb"
	postgresstore "github.com/latentsignal-org/periscope/internal/postgres"
)

var (
	_ db.Store = (*db.DB)(nil)
	_ db.Store = (*postgresstore.Store)(nil)
	_ db.Store = (*duckdbstore.Store)(nil)
)
