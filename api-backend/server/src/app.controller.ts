import { Controller, Get } from '@nestjs/common';

@Controller()
export class AppController {
  @Get()
  getRoot() {
    return { status: 'ok', message: 'EduLoan API Service' };
  }

  @Get('health')
  health() {
    return { status: 'ok' };
  }
}
