<?php

namespace App\Http\Controllers\Concerns;

use App\Models\Agency;
use Illuminate\Http\Request;
use Symfony\Component\HttpKernel\Exception\HttpException;

trait ResolvesAgency
{
    /** The agency the current authenticated agency-staff user belongs to. */
    protected function currentAgency(Request $request): Agency
    {
        $agency = $request->user()->agencyStaff?->agency;

        if (! $agency) {
            throw new HttpException(403, 'Your account is not linked to an agency.');
        }

        return $agency;
    }
}
