import { Injectable } from '@nestjs/common';

@Injectable()
export class EvvEngineService {
  async computeFullEvv(
    fileBuffer: Buffer,
    mimeType: string,
    fileName: string,
    applicationId: string,
  ): Promise<any> {
    return {
      status: 'COMPUTED',
      overallEvv: 15000,
      monthly_evv: [],
      totalSnapshots: 6,
      totalTransactions: 120,
      period: '6 Months',
    };
  }
}
