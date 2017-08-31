export default class FilteredSearchServiceDesk extends gl.FilteredSearchManager {
  constructor() {
    super('service_desk');
  }

  customRemovalValidator(token) {
    return token.querySelector('.value-container').getAttribute('data-original-value') !== '@support-bot';
  };

  canEdit(tokenName) {
    return tokenName !== 'author';
  }

  modifyUrlParams(paramsArray) {
    const authorParamKey = 'author_username';
    // FIXME: Need to grab the value from a data attribute
    const supportBotParamPair = `${authorParamKey}=support-bot`;

    const onlyValidParams = paramsArray.filter((param) => {
      return param.indexOf(authorParamKey) === -1;
    });

    onlyValidParams.push(supportBotParamPair);

    return onlyValidParams;
  }
}

