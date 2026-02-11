// services/razorpayService.js
import Razorpay from 'razorpay';
import crypto from 'crypto';
import logger from '../utils/logger.js';

class RazorpayService {
  constructor() {
    // Add debug logging for credentials
    console.log('Razorpay Config:', {
      key_id: process.env.RAZORPAY_KEY_ID ? 'Set' : 'Missing',
      key_secret: process.env.RAZORPAY_KEY_SECRET ? 'Set' : 'Missing'
    });
    
    try {
      this.razorpay = new Razorpay({
        key_id: process.env.RAZORPAY_KEY_ID,
        key_secret: process.env.RAZORPAY_KEY_SECRET
      });
      logger.info('Razorpay initialized successfully');
    } catch (error) {
      logger.error('Failed to initialize Razorpay:', error);
      throw error;
    }
  }

  async createOrder(amount, currency = 'INR') {
    try {
      // Validate amount
      if (!amount || amount <= 0) {
        throw new Error('Invalid amount provided');
      }
      
      // Razorpay expects amount in paise (₹1 = 100 paise)
      const amountInPaise = Math.round(amount * 100);
      
      // Ensure minimum amount (Razorpay minimum is 100 paise = ₹1)
      if (amountInPaise < 100) {
        throw new Error('Amount must be at least ₹1');
      }

      const options = {
        amount: amountInPaise,
        currency,
        receipt: `receipt_${Date.now()}`,
        notes: {
          source: 'jaga-garments'
        }
      };

      logger.info(`Creating Razorpay order with options:`, {
        amount: options.amount,
        currency: options.currency,
        receipt: options.receipt
      });

      const order = await this.razorpay.orders.create(options);
      logger.info(`Razorpay order created successfully: ${order.id}`);
      
      return order;
    } catch (error) {
      logger.error('Error creating Razorpay order:', {
        error: error.message,
        stack: error.stack,
        amount,
        currency
      });
      
      // More specific error messages
      if (error.error && error.error.description) {
        throw new Error(`Razorpay error: ${error.error.description}`);
      } else if (error.message.includes('key_id')) {
        throw new Error('Invalid Razorpay credentials. Please check RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET.');
      } else if (error.message.includes('network')) {
        throw new Error('Network error connecting to Razorpay. Please check your internet connection.');
      } else {
        throw new Error(`Failed to create payment order: ${error.message}`);
      }
    }
  }

  verifyPayment(razorpay_order_id, razorpay_payment_id, razorpay_signature) {
    try {
      if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
        logger.warn('Missing payment verification parameters');
        return false;
      }

      const body = razorpay_order_id + "|" + razorpay_payment_id;
      const expectedSignature = crypto
        .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
        .update(body.toString())
        .digest('hex');

      const isValid = expectedSignature === razorpay_signature;
      
      if (!isValid) {
        logger.warn(`Payment verification failed for order: ${razorpay_order_id}`);
        logger.debug('Signature comparison:', {
          expected: expectedSignature,
          received: razorpay_signature,
          body: body
        });
      } else {
        logger.info(`Payment verified successfully for order: ${razorpay_order_id}`);
      }
      
      return isValid;
    } catch (error) {
      logger.error('Error verifying payment:', error);
      return false;
    }
  }

  async refundPayment(paymentId, amount, notes = {}) {
    try {
      const amountInPaise = Math.round(amount * 100);
      
      if (amountInPaise < 100) {
        throw new Error('Refund amount must be at least ₹1');
      }

      const refund = await this.razorpay.payments.refund(paymentId, {
        amount: amountInPaise,
        notes
      });
      
      logger.info(`Refund processed: ${refund.id} for payment: ${paymentId}`);
      return refund;
    } catch (error) {
      logger.error('Error processing refund:', error);
      throw new Error('Refund processing failed');
    }
  }
}

export default new RazorpayService();