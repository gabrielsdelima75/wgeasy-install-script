const bcrypt = require('bcryptjs');

// Função para gerar o hash
const generateHash = async (password) => {
  try {
    const salt = await bcrypt.genSalt(12);
    const hash = await bcrypt.hash(password, salt);
    return `PASSWORD_HASH='${hash}'`;  // Retorna o hash em vez de imprimir
  } catch (error) {
    throw new Error(`Falha ao gerar o hash: ${error}`);
  }
};

const main = async () => {
  const password = process.argv[2];  // Obtém a senha da linha de comando
  if (!password) {
    console.error('Senha não fornecida');
    process.exit(1);
  }
  const hash = await generateHash(password);
  console.log(hash);  // Imprime o hash para que o shell capture
};

main();