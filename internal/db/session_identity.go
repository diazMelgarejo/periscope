package db

import "github.com/latentsignal-org/periscope/internal/parser"

// ApplyParsedSessionIdentity copies parser-owned session identity onto a DB session.
func ApplyParsedSessionIdentity(dst *Session, src parser.ParsedSession) {
	dst.Agent = string(src.Agent)
	dst.AgentLabel = src.AgentLabel
	dst.Entrypoint = src.Entrypoint
}
