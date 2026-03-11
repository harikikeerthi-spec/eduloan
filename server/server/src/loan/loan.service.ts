import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class LoanService {
    constructor(private prisma: PrismaService) { }

    /**
     * Create a new loan application
     */
    async createLoan(data: {
        userId: string;
        applicantName: string;
        phoneNumber: string;
        email: string;
        institute: string;
        course: string;
        amount: number;
        tenure: number;
    }) {
        const applicationNumber = 'APP' + Date.now() + Math.floor(Math.random() * 1000);
        const loan = await this.prisma.loanApplication.create({
            data: {
                userId: data.userId,
                firstName: data.applicantName,
                phone: data.phoneNumber,
                email: data.email,
                universityName: data.institute,
                courseName: data.course,
                bank: 'Pending Assignment',
                loanType: 'education',
                amount: data.amount,
                tenure: data.tenure,
                status: 'pending',
                progress: 10,
                applicationNumber,
            },
        });

        return {
            success: true,
            message: 'Loan application submitted successfully',
            data: loan,
        };
    }

    /**
     * Get all loans for a specific user
     */
    async getUserLoans(userId: string) {
        const loans = await this.prisma.loanApplication.findMany({
            where: { userId },
            orderBy: { date: 'desc' },
        });

        return {
            success: true,
            data: loans,
        };
    }

    /**
     * Get loan by ID
     */
    async getLoanById(id: string) {
        const loan = await this.prisma.loanApplication.findUnique({
            where: { id },
        });

        if (!loan) {
            throw new NotFoundException('Loan application not found');
        }

        return {
            success: true,
            data: loan,
        };
    }

    /**
     * Update loan status and progress
     */
    async updateLoanStatus(
        id: string,
        updates: { status?: string; progress?: number },
    ) {
        const loan = await this.prisma.loanApplication.findUnique({
            where: { id },
        });

        if (!loan) {
            throw new NotFoundException('Loan application not found');
        }

        const updatedLoan = await this.prisma.loanApplication.update({
            where: { id },
            data: updates,
        });

        return {
            success: true,
            message: 'Loan status updated successfully',
            data: updatedLoan,
        };
    }
}
