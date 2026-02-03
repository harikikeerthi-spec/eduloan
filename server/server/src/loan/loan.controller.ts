import { Controller, Get, Post, Body, Param, Patch } from '@nestjs/common';
import { LoanService } from './loan.service';

@Controller('loans')
export class LoanController {
    constructor(private readonly loanService: LoanService) { }

    /**
     * Create a new loan application
     * POST /loans
     */
    @Post()
    async createLoan(@Body() body: {
        userId: string;
        applicantName: string;
        phoneNumber: string;
        email: string;
        institute: string;
        course: string;
        amount: number;
        tenure: number;
    }) {
        return this.loanService.createLoan(body);
    }

    /**
     * Get all loans for a user
     * GET /loans/user/:userId
     */
    @Get('user/:userId')
    async getUserLoans(@Param('userId') userId: string) {
        return this.loanService.getUserLoans(userId);
    }

    /**
     * Get loan by ID
     * GET /loans/:id
     */
    @Get(':id')
    async getLoanById(@Param('id') id: string) {
        return this.loanService.getLoanById(id);
    }

    /**
     * Update loan status and progress
     * PATCH /loans/:id/status
     */
    @Patch(':id/status')
    async updateLoanStatus(
        @Param('id') id: string,
        @Body() body: { status?: string; progress?: number },
    ) {
        return this.loanService.updateLoanStatus(id, body);
    }
}
