<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AuditLog;
use App\Services\AiAssistantService;
use Illuminate\Http\Request;
use RuntimeException;
use Symfony\Component\HttpKernel\Exception\HttpException;

class AssistantController extends Controller
{
    public function ask(Request $request)
    {
        $data = $request->validate([
            'message' => ['required', 'string', 'max:1000'],
            'history' => ['sometimes', 'array', 'max:20'],
            'history.*.role' => ['required_with:history', 'string', 'in:user,assistant'],
            'history.*.content' => ['required_with:history', 'string'],
        ]);

        if (! AiAssistantService::isConfigured()) {
            throw new HttpException(503, 'The AI assistant is not configured yet. Please try again later.');
        }

        $service = new AiAssistantService($request->user());

        try {
            $result = $service->ask($data['message'], $data['history'] ?? []);
        } catch (RuntimeException $e) {
            throw new HttpException(502, 'The AI assistant could not answer right now. Please try again.');
        }

        AuditLog::record($request->user(), 'assistant.query', null, $data['message']);

        return response()->json($result);
    }
}
