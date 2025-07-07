/**
 * Unit tests for email validation functionality
 */

// Mock DOM environment
document.body.innerHTML = `
  <form id="emailForm">
    <input type="email" id="email" placeholder="Enter your email" required>
    <button type="submit">Notify Me</button>
    <p class="error-message" id="error-message"></p>
  </form>
`;

// Import the validation logic
const validateEmail = (email) => {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
};

const validateForm = (emailInput, errorMessage) => {
  if (!emailInput.value) {
    errorMessage.textContent = "Please enter an email address.";
    return false;
  } else if (!validateEmail(emailInput.value)) {
    errorMessage.textContent = "Please enter a valid email address.";
    return false;
  } else {
    errorMessage.textContent = "";
    return true;
  }
};

describe('Email Validation Tests', () => {
  let emailInput;
  let errorMessage;
  let form;

  beforeEach(() => {
    emailInput = document.getElementById('email');
    errorMessage = document.getElementById('error-message');
    form = document.getElementById('emailForm');
    
    // Reset form state
    emailInput.value = '';
    errorMessage.textContent = '';
  });

  describe('validateEmail function', () => {
    test('should return true for valid email addresses', () => {
      const validEmails = [
        'test@example.com',
        'user.name@domain.co.uk',
        'user+tag@example.org',
        '123@numbers.com'
      ];

      validEmails.forEach(email => {
        expect(validateEmail(email)).toBe(true);
      });
    });

    test('should return false for invalid email addresses', () => {
      const invalidEmails = [
        'invalid-email',
        '@example.com',
        'user@',
        'user@.com',
        'user..name@example.com',
        'user@example..com'
      ];

      invalidEmails.forEach(email => {
        expect(validateEmail(email)).toBe(false);
      });
    });
  });

  describe('validateForm function', () => {
    test('should return false and show error for empty email', () => {
      emailInput.value = '';
      
      const result = validateForm(emailInput, errorMessage);
      
      expect(result).toBe(false);
      expect(errorMessage.textContent).toBe('Please enter an email address.');
    });

    test('should return false and show error for invalid email format', () => {
      emailInput.value = 'invalid-email';
      
      const result = validateForm(emailInput, errorMessage);
      
      expect(result).toBe(false);
      expect(errorMessage.textContent).toBe('Please enter a valid email address.');
    });

    test('should return true and clear error for valid email', () => {
      emailInput.value = 'test@example.com';
      
      const result = validateForm(emailInput, errorMessage);
      
      expect(result).toBe(true);
      expect(errorMessage.textContent).toBe('');
    });
  });

  describe('Form submission behavior', () => {
    test('should prevent form submission for invalid email', () => {
      const mockPreventDefault = jest.fn();
      emailInput.value = 'invalid-email';
      
      // Simulate form submission
      const event = {
        preventDefault: mockPreventDefault
      };
      
      const result = validateForm(emailInput, errorMessage);
      
      if (!result) {
        event.preventDefault();
      }
      
      expect(mockPreventDefault).toHaveBeenCalled();
      expect(errorMessage.textContent).toBe('Please enter a valid email address.');
    });

    test('should allow form submission for valid email', () => {
      const mockPreventDefault = jest.fn();
      emailInput.value = 'test@example.com';
      
      // Simulate form submission
      const event = {
        preventDefault: mockPreventDefault
      };
      
      const result = validateForm(emailInput, errorMessage);
      
      if (!result) {
        event.preventDefault();
      }
      
      expect(mockPreventDefault).not.toHaveBeenCalled();
      expect(errorMessage.textContent).toBe('');
    });
  });
}); 