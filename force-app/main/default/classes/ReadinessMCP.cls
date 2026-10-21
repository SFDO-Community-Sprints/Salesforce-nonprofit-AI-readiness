public with sharing class ReadinessMCP {
    public class Request {
        @InvocableVariable(required=true label='Fixed assessment scenario' description='organization, poor, improving, pilot, blocked or unknown only.')
        public String scenario;
    }
    public class Response {
        @InvocableVariable(label='Aggregate assessment' description='Fixed counts and calculated data checks only; no records, staff evidence or write actions.')
        public String output;
    }
    @InvocableMethod(label='Read Nonprofit Readiness Aggregates' description='Read sharing-scoped aggregate data checks through a dedicated permission boundary. No raw records or writes.')
    public static List<Response> assess(List<Request> requests) {
        List<Response> results = new List<Response>();
        Map<String,String> cache = new Map<String,String>();
        if (requests == null) return results;
        for (Request request : requests) {
            Response response = new Response();
            String scenario = request == null ? null : request.scenario;
            if (!cache.containsKey(scenario)) cache.put(scenario,NonprofitAIReadiness.assessMcpScenario(scenario));
            response.output = cache.get(scenario);
            results.add(response);
        }
        return results;
    }
}
