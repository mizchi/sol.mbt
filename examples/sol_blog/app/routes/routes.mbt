///| SSG-only project - minimal routes for build compatibility
pub fn routes() -> Array[@router.SolRoutes] {
  []
}

///| Action registry (empty for SSG)
pub fn action_registry() -> @action.ActionRegistry {
  @action.ActionRegistry::new(allowed_origins=[])
}

///| Router configuration
pub fn config() -> @router.RouterConfig {
  @router.RouterConfig::default()
}
