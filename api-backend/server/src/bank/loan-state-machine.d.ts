export type LoanStatus = 'pending' | 'docs_received' | 'staff_verified' | 'submitted_to_bank' | 'file_logged' | 'under_bank_review' | 'query_raised' | 'approved' | 'sanctioned' | 'conditional_sanction' | 'partial_sanction' | 'counter_offer' | 'rejected' | 'disbursement_confirmed' | 'closed' | 'expired';
export interface StateTransition {
    from: LoanStatus[];
    to: LoanStatus;
    allowedRoles: string[];
}
export declare class LoanStateMachine {
    private static readonly transitions;
    static validateTransition(currentStatus: string, targetStatus: string, userRole: string): void;
    static getProgressByStatus(status: string): number;
    static getStageByStatus(status: string): string;
    static getAllowedTransitions(currentStatus: string, userRole: string): LoanStatus[];
    static isTerminalState(status: string): boolean;
}
