// * added this helper so I don't have to type queries over and over and over again because this thing handles so much data

/**
 * @param {Object} getParam
 * @param {Function} getParam.getFunction
 * @param {String} getParam.objectType
 * @param {String} getParam.fields
 * @param {Boolean} getParam.hasConditions
 * @param {String} [getParam.conditions]
 */
const getMLRecord = async (getParam) => {
  const conditions = getParam.hasConditions ? getParam.conditions : "";
  const query = `SELECT ${getParam.fields} FROM ${getParam.objectType} ${conditions}`;
  try {
    const result = await getParam.getFunction({ queryString: query });
    return [result, null];
  } catch (err) {
    return [null, err];
  }
};
export { getMLRecord };