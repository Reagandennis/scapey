class AiService {
  // Placeholder for calling LLM API directly or using MCP layer
  Future<String> generateMissionPlan(String input) async {
    await Future.delayed(const Duration(seconds: 1)); // Mock delay
    return 'Generated plan for: $input';
  }
}
