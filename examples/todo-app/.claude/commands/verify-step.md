# 現在のステップを検証

Verify that the current step has completed successfully by checking:
1. All required artifacts exist
2. All verification rules pass  
3. Orchestrator is updated

This command will:
- Check .vibe/state.yaml to identify current step
- Load verification rules from .vibe/verification_rules.yaml
- Check all post_conditions for the current step
- Update .vibe/orchestrator.yaml with results
- Block progression if verification fails

Show verification results in Japanese with clear pass/fail indicators.
