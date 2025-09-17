// utils/mathCalculator.ts
export function safeCalculate(input: string): number | null {

  if (input === "") {
    return 0
  }
  
  if (!input.trim()) {
    return null;
  }

  // Enhanced validation to catch more invalid patterns
  if (!/^[-+*/() \d.]+$/.test(input)) {
    return null;
  }

  try {
    // Clean the input and add spaces around operators for easier tokenization
    const cleaned = input.replace(/\s+/g, '')
      .replace(/([+\-*/()])/g, ' $1 ')
      .trim();

    // Tokenize with proper handling of negative numbers
    const tokens = cleaned.split(/\s+/).filter(t => t !== '');

    // Convert to Reverse Polish Notation using Shunting-yard algorithm
    const outputQueue: (number | string)[] = [];
    const operatorStack: string[] = [];

    const precedence: Record<string, number> = {
      '+': 2,
      '-': 2,
      '*': 3,
      '/': 3
    };

    for (let i = 0; i < tokens.length; i++) {
      const token = tokens[i];

      // Handle numbers (including negative numbers)
      if (/^-?\d+\.?\d*$/.test(token)) {
        outputQueue.push(parseFloat(token));
      }
      // Handle operators
      else if (/^[+\-*/]$/.test(token)) {
        // Special case for subtraction vs negative number
        if (token === '-' && (i === 0 || /^[+\-*/(]$/.test(tokens[i-1]))) {
          // This is a negative sign, not subtraction
          if (/^-?\d+\.?\d*$/.test(tokens[i+1])) {
            outputQueue.push(parseFloat(token + tokens[++i]));
            continue;
          }
          return null;
        }

        while (
          operatorStack.length > 0 &&
            operatorStack[operatorStack.length - 1] !== '(' &&
            precedence[operatorStack[operatorStack.length - 1]] >= precedence[token]
        ) {
          outputQueue.push(operatorStack.pop()!);
        }
        operatorStack.push(token);
      }
      // Handle parentheses
      else if (token === '(') {
        operatorStack.push(token);
      } else if (token === ')') {
        while (operatorStack.length > 0 && operatorStack[operatorStack.length - 1] !== '(') {
          outputQueue.push(operatorStack.pop()!);
        }
        if (operatorStack.pop() !== '(') {
          return null;
        } // Mismatched parentheses
      } else {
        return null; // Invalid token
      }
    }

    // Push remaining operators
    while (operatorStack.length > 0) {
      const op = operatorStack.pop()!;
      if (op === '(') {
        return null;
      } // Unclosed parenthesis
      outputQueue.push(op);
    }

    // Evaluate RPN
    const stack: number[] = [];
    for (const token of outputQueue) {
      if (typeof token === 'number') {
        stack.push(token);
      } else {
        const b = stack.pop();
        const a = stack.pop();
        if (a === undefined || b === undefined) {
          return null;
        }

        switch (token) {
          case '+':
            stack.push(a + b);
            break;
          case '-':
            stack.push(a - b);
            break;
          case '*':
            stack.push(a * b);
            break;
          case '/':
            if (b === 0) {
              return null;
            }
            stack.push(a / b);
            break;
          default:
            return null;
        }
      }
    }

    return stack.length === 1 ? stack[0] : null;
  } catch {
    return null;
  }
}