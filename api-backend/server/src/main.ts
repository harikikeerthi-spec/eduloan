import 'reflect-metadata';
import 'dotenv/config';
import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import * as express from 'express';
import helmet from 'helmet';

async function bootstrap() {
  const app = await NestFactory.create(AppModule);
  
  // 1. Bank-Grade HTTP Security Headers (HSTS, nosniff, x-frame-options)
  app.use(helmet({
    crossOriginEmbedderPolicy: false,
    crossOriginResourcePolicy: { policy: "cross-origin" },
  }));

  app.setGlobalPrefix('api');
  app.enableCors();

  // ✅ CRITICAL: Twilio sends webhooks as application/x-www-form-urlencoded
  // Without this, body.From and body.Body will always be undefined
  app.use(express.urlencoded({ extended: true }));
  app.use(express.json());
  
  const port = process.env.PORT || 5000;
  await app.listen(port, '0.0.0.0');
  
  console.log(`Server running on port ${port}`);
  console.log(`Android Emulator: http://10.0.2.2:${port}`);
  console.log(`WhatsApp Webhook URL: http://localhost:${port}/api/webhook/whatsapp`);
  console.log(`WhatsApp Webhook URL (alt): http://localhost:${port}/api/whatsapp`);
}
bootstrap();
