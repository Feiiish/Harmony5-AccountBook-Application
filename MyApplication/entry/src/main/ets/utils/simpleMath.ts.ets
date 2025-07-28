// utils/mathCalculator.ts
export function safeCalculate(input: string): number | null {
  // 1. 空值检查
  if (!input.trim()) {
    return null;
  }

  // 2. 逐字符验证
  const validChars = /^[\d+\-*/. ]+$/; // 允许数字、运算符、空格和小数点
  if (!validChars.test(input)) {
    return null;
  }

  // 3. 提取所有有效token（支持带符号的数字）
  const tokens = input
    .split(/([+\-*/])/)// 按运算符分割
    .filter(token => token.trim() !== ''); // 移除空token

  // 4. 验证token结构
  for (let i = 0; i < tokens.length; i++) {
    const token = tokens[i];

    // 奇数位应为运算符（首个token除外）
    if (i % 2 === 1 && !/^[+\-*/]$/.test(token)) {
      return null; // 运算符位置出现非法字符
    }

    // 偶数位应为数字（含符号）
    if (i % 2 === 0 && !/^[+-]?\d*\.?\d+$/.test(token)) {
      return null; // 数字位置格式错误
    }
  }

  // 5. 计算结果
  try {
    // 单数字情况
    if (tokens.length === 1) {
      return parseFloat(tokens[0]);
    }

    // 简单运算（示例仅处理两个数字的情况，可扩展为完整计算器逻辑）
    if (tokens.length === 3) {
      const num1 = parseFloat(tokens[0]);
      const op = tokens[1];
      const num2 = parseFloat(tokens[2]);

      switch (op) {
        case '+':
          return num1 + num2;
        case '-':
          return num1 - num2;
        case '*':
          return num1 * num2;
        case '/':
          return num2 !== 0 ? num1 / num2 : null;
        default:
          return null;
      }
    }

    return null; // 复杂运算暂不支持
  } catch {
    return null;
  }
}