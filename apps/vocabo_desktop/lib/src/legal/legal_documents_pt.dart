import 'legal_documents.dart';

const _updatedOnPt = '11 de outubro de 2026';

const privacyPolicyPt = LegalDocument(
  title: 'Política de Privacidade',
  updatedOn: _updatedOnPt,
  intro:
      'O Vocabo é um aplicativo de vocabulário em inglês operado pela '
      '$companyName ("nós"). Esta política explica quais dados pessoais '
      'coletamos, por que os coletamos, quem os trata em nosso nome e quais '
      'são os seus direitos como titular. Somos o controlador dos seus dados '
      'pessoais nos termos da Lei Geral de Proteção de Dados Pessoais (LGPD, '
      'Lei nº 13.709/2018) e, quando aplicável, do Regulamento Geral sobre a '
      'Proteção de Dados da União Europeia (GDPR).',
  sections: [
    LegalSection('1. Dados que coletamos', [
      'Dados de cadastro: seu nome, endereço de e-mail e senha. As senhas são '
          'armazenadas apenas na forma de hash seguro e irreversível. '
          'Opcionalmente, seu número de telefone, idade, foto de perfil e '
          'idioma nativo.',
      'Dados de aprendizado: as palavras da sua biblioteca, as palavras que '
          'você mesmo cria, suas revisões de flashcards, respostas e '
          'progresso, as palavras que você pesquisa no spotlight de tradução '
          'e suas preferências no aplicativo, como os horários de lembrete.',
      'Dados de dispositivo e de segurança: o nome e o sistema operacional de '
          'cada dispositivo conectado, a versão do aplicativo, o endereço IP, '
          'o user agent e o horário do último uso de cada sessão.',
      'Login com Google ou Apple: seu nome, endereço de e-mail e um '
          'identificador de conta fornecidos pelo Google ou pela Apple. Nunca '
          'recebemos a sua senha do Google ou da Apple.',
      'Não utilizamos identificadores de publicidade, não rastreamos você em '
          'outros aplicativos ou sites e não coletamos dados de cartão de '
          'pagamento.',
    ]),
    LegalSection('2. Como e por que utilizamos os dados', [
      'Para prestar o serviço (execução de contrato): criar e proteger a sua '
          'conta, manter a sua biblioteca e o seu progresso sincronizados '
          'entre dispositivos, programar os seus flashcards e gerar traduções, '
          'definições e pronúncias para novas palavras.',
      'Para proteger a sua conta (legítimo interesse): verificar o seu e-mail '
          'ou telefone, enviar códigos de acesso e de redefinição de senha, '
          'limitar o número de dispositivos conectados e detectar abusos.',
      'Para cumprir obrigações legais ou regulatórias, como a guarda de '
          'registros exigida por lei.',
      'Não vendemos os seus dados pessoais e não os utilizamos para '
          'publicidade.',
    ]),
    LegalSection('3. Prestadores de serviços (operadores)', [
      'Compartilhamos dados apenas com prestadores que nos ajudam a operar o '
          'Vocabo, por contratos que os limitam a essa finalidade:',
      'Provedores de inteligência artificial geram traduções, definições, '
          'exemplos e o áudio de pronúncia. Eles recebem apenas a palavra '
          'consultada e o idioma de destino, nunca o seu nome, e-mail ou '
          'outros dados da conta.',
      'Provedores de infraestrutura em nuvem hospedam nossos servidores e '
          'bancos de dados. Provedores de comunicação entregam os códigos de '
          'verificação por e-mail e SMS e recebem apenas o endereço ou o '
          'número de destino.',
      'O Google e a Apple tratam o seu login quando você escolhe essas '
          'opções, de acordo com as respectivas políticas de privacidade.',
      'As traduções feitas pela barra de menus ou pelo spotlight podem '
          'utilizar o Apple Translation (Tradução da Apple), que é executado '
          'no seu Mac.',
      'A lista atualizada de prestadores pode ser solicitada pelo e-mail '
          '$supportEmail.',
    ]),
    LegalSection('4. Transferência internacional de dados', [
      'Alguns desses prestadores tratam dados fora do Brasil, por exemplo na '
          'União Europeia e nos Estados Unidos. Essas transferências '
          'internacionais se apoiam nas salvaguardas admitidas pela LGPD e '
          'pelo GDPR, como as cláusulas-padrão contratuais.',
    ]),
    LegalSection('5. Por quanto tempo mantemos os dados', [
      'Mantemos os seus dados enquanto a sua conta existir. Quando você exclui '
          'a sua conta, o seu perfil, biblioteca, flashcards, progresso, '
          'histórico de traduções e foto são eliminados imediatamente dos '
          'nossos sistemas. As cópias de segurança (backups) são sobrescritas '
          'em até 30 (trinta) dias. Os registros de conexão e de acesso '
          'são mantidos por 6 (seis) meses, conforme exige o Marco Civil da '
          'Internet (Lei 12.965/2014).',
    ]),
    LegalSection('6. Segurança', [
      'Os dados trafegam por conexões criptografadas. O seu token de acesso é '
          'armazenado no Keychain (Acesso às Chaves) do macOS. O acesso aos '
          'nossos servidores é restrito às pessoas que operam o serviço.',
    ]),
    LegalSection('7. Seus direitos', [
      'Como titular, você pode confirmar a existência de tratamento dos seus '
          'dados, acessá-los, corrigi-los, solicitar uma cópia em formato que '
          'permita a portabilidade, pedir a eliminação, revogar o '
          'consentimento e se opor ao tratamento realizado com base no '
          'legítimo interesse.',
      'Você mesmo pode editar o seu perfil, desconectar dispositivos e excluir '
          'a sua conta em Ajustes, no aplicativo. Para '
          'qualquer outra solicitação, escreva para $supportEmail. Respondemos '
          'em até 15 (quinze) dias.',
      'Você também pode apresentar reclamação à Autoridade Nacional de '
          'Proteção de Dados (ANPD) ou à autoridade de proteção de dados do '
          'seu país.',
    ]),
    LegalSection('8. Crianças', [
      'O Vocabo não é direcionado a menores de 13 anos, e não coletamos '
          'intencionalmente dados dessas pessoas. Se você acredita que uma '
          'criança criou uma conta, entre em contato conosco e nós a '
          'excluiremos.',
    ]),
    LegalSection('9. Alterações desta política', [
      'Atualizaremos esta página e a data acima sempre que esta política for '
          'alterada. Alterações relevantes serão comunicadas no aplicativo '
          'antes de entrarem em vigor.',
    ]),
    LegalSection('10. Contato', [
      '$companyName, $supportEmail. Este endereço também é o canal de contato '
          'do nosso encarregado pelo tratamento de dados pessoais (DPO).',
    ]),
  ],
);

const termsOfServicePt = LegalDocument(
  title: 'Termos de Uso',
  updatedOn: _updatedOnPt,
  intro:
      'Estes termos regem o uso do Vocabo, aplicativo operado pela '
      '$companyName. Ao criar uma conta ou utilizar o aplicativo, você '
      'concorda com eles. Se não concordar, não utilize o Vocabo.',
  sections: [
    LegalSection('1. Elegibilidade', [
      'Você deve ter pelo menos 13 anos de idade para usar o Vocabo. Se tiver '
          'menos de 18 anos, precisa da autorização dos seus pais ou do seu '
          'responsável legal.',
    ]),
    LegalSection('2. Sua conta', [
      'Forneça informações verdadeiras e mantenha a sua senha em segurança. '
          'Você é responsável pelas atividades realizadas na sua conta. '
          'Avise-nos imediatamente pelo e-mail $supportEmail se suspeitar de '
          'uso não autorizado.',
      'Uma conta pode permanecer conectada em até três dispositivos ao mesmo '
          'tempo. Ao entrar em um novo dispositivo, a sessão do dispositivo '
          'mais antigo é encerrada.',
    ]),
    LegalSection('3. Licença', [
      'Concedemos a você uma licença pessoal, não exclusiva, intransferível e '
          'revogável para usar o Vocabo no seu próprio aprendizado de idiomas. '
          'O aplicativo, o seu design, conteúdo e marca pertencem à '
          '$companyName.',
    ]),
    LegalSection('4. Uso aceitável', [
      'Não utilize o Vocabo para violar a lei, infringir direitos de terceiros '
          'ou enviar conteúdo abusivo. Não tente acessar o serviço por outros '
          'meios que não o aplicativo, nem realizar engenharia reversa, '
          'sobrecarregá-lo, extrair dados de forma automatizada (scraping) ou '
          'contornar os seus limites e medidas de segurança.',
    ]),
    LegalSection('5. Seu conteúdo', [
      'As palavras, traduções e exemplos que você cria continuam sendo seus. '
          'Você nos concede a autorização necessária para armazená-los e '
          'exibi-los a você, de modo que o serviço funcione.',
    ]),
    LegalSection('6. Conteúdo gerado automaticamente', [
      'Traduções, definições, exemplos e áudios são gerados automaticamente, '
          'em parte com inteligência artificial, e podem conter erros. Eles '
          'servem como apoio ao aprendizado e não constituem tradução '
          'profissional nem aconselhamento.',
    ]),
    LegalSection('7. Planos e pagamentos', [
      'O Vocabo oferece um plano gratuito. Os planos pagos, quando '
          'disponíveis, informarão o preço, a periodicidade de cobrança e as '
          'funcionalidades antes da contratação. As assinaturas adquiridas '
          'pela App Store são cobradas e renovadas pela Apple, de acordo com '
          'os termos dela, e podem ser canceladas nas configurações da sua '
          'conta Apple com pelo menos 24 horas de antecedência da renovação.',
      'Podemos alterar as funcionalidades do plano gratuito. Alterações em um '
          'plano pago já contratado só produzirão efeitos a partir do período '
          'de cobrança seguinte, mediante aviso prévio.',
    ]),
    LegalSection('8. Disponibilidade e alterações', [
      'Trabalhamos para manter o Vocabo disponível, mas não podemos garantir '
          'que ele funcionará sempre sem interrupções ou erros. Podemos '
          'alterar, suspender ou descontinuar funcionalidades e, sempre que '
          'possível, avisaremos com antecedência razoável sobre alterações '
          'relevantes.',
    ]),
    LegalSection('9. Encerramento da conta', [
      'Você pode excluir a sua conta a qualquer momento em Ajustes > '
          'Segurança da conta. Podemos suspender ou encerrar contas que violem estes '
          'termos, mediante aviso prévio quando a lei o exigir.',
    ]),
    LegalSection('10. Isenção e limitação de responsabilidade', [
      'Na máxima extensão permitida pela lei, o Vocabo é fornecido "no estado '
          'em que se encontra", e a $companyName não se responsabiliza por '
          'danos indiretos, incidentais ou consequenciais, nem por perda de '
          'dados ou de lucros decorrentes do uso do aplicativo. Nada nestes '
          'termos limita direitos irrenunciáveis assegurados pela legislação '
          'de proteção ao consumidor, em especial pelo Código de Defesa do '
          'Consumidor (Lei nº 8.078/1990).',
    ]),
    LegalSection('11. Privacidade', [
      'A forma como tratamos os seus dados pessoais está descrita na Política '
          'de Privacidade, que integra estes termos.',
    ]),
    LegalSection('12. Alterações destes termos', [
      'Podemos atualizar estes termos. A data acima indica a versão mais '
          'recente, e alterações relevantes serão comunicadas no aplicativo. '
          'Ao continuar usando o Vocabo após uma alteração, você aceita os '
          'novos termos.',
    ]),
    LegalSection('13. Lei aplicável e foro', [
      'Estes termos são regidos pelas leis da República Federativa do Brasil. '
          'Fica eleito o foro da Comarca de São Paulo/SP para dirimir '
          'quaisquer controvérsias decorrentes destes termos, ressalvado ao '
          'consumidor o direito de propor a ação no foro do seu domicílio, '
          'nos termos do Código de Defesa do Consumidor.',
      'Consumidores residentes em outros países também podem se valer das '
          'proteções obrigatórias do país em que residem e propor ações '
          'perante os tribunais locais.',
    ]),
    LegalSection('14. Contato', ['$companyName, $supportEmail.']),
  ],
);
