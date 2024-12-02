const bcrypt = require('bcrypt');
const password = process.argv[2]; // A senha fornecida como argumento

bcrypt.hash(password, 10, (err, hash) => {
  if (err) {
    console.error('Erro ao gerar o hash:', err);
    process.exit(1);
  } else {
    console.log(hash);
    process.exit(0);
  }
});