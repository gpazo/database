BEGIN;

SELECT dropIfExists('FUNCTION', 'grantpriv(integer, integer)');
SELECT dropIfExists('FUNCTION', 'grantallmodulepriv(integer, text)');
SELECT dropIfExists('FUNCTION', 'updatetodoitem(INTEGER, INTEGER, TEXT, TEXT, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, BOOLEAN)');
SELECT dropIfExists('FUNCTION', 'updateTodoItem(INTEGER, INTEGER, TEXT, TEXT, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, BOOLEAN)');
SELECT dropIfExists('FUNCTION', 'updateTodoItem(INTEGER, INTEGER, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER, DATE, DATE, INTEGER, TEXT, BOOLEAN)');
SELECT dropIfExists('FUNCTION', 'updateTodoItem(INTEGER, INTEGER, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, BOOLEAN, TEXT)');
SELECT dropIfExists('FUNCTION', 'createTodoItem(INTEGER, TEXT, TEXT, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT)', 'public');
SELECT dropIfExists('FUNCTION', 'createTodoItem(INTEGER, TEXT, TEXT, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT)', 'public');
SELECT dropIfExists('FUNCTION', 'createTodoItem(INTEGER, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT)', 'public');
SELECT dropIfExists('FUNCTION', 'createTodoItem(INTEGER, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, TEXT)', 'public');
SELECT dropIfExists('FUNCTION', 'createTodoItem(INTEGER, INTEGER, TEXT, TEXT, INTEGER, INTEGER, INTEGER, DATE, DATE, CHARACTER(1), DATE, DATE, INTEGER, TEXT, TEXT)', 'public');
SELECT dropIfExists('FUNCTION', 'logWOTCEvent(INTEGER, INTEGER, TEXT)');
SELECT dropIfExists('FUNCTION', 'currentUserId()');
SELECT dropIfExists('FUNCTION', 'getUsername(INTEGER)');
SELECT dropIfExists('FUNCTION', 'triggeritemcost()');
SELECT dropIfExists('FUNCTION', 'getUsrId(text)');
SELECT dropIfExists('FUNCTION', 'setUserPreference(INTEGER, TEXT, TEXT)');
SELECT dropIfExists('FUNCTION', 'revokePriv(INTEGER, INTEGER)');
SELECT dropIfExists('FUNCTION', 'revokeAllModulePriv(INTEGER, TEXT)');
SELECT dropIfExists('FUNCTION', 'itemPrice(INTEGER, INTEGER, NUMERIC)');
SELECT dropIfExists('FUNCTION', 'itemPrice(INTEGER, INTEGER, INTEGER, NUMERIC)');
SELECT dropIfExists('FUNCTION', 'itemPrice(INTEGER, INTEGER, INTEGER, NUMERIC, INTEGER)');
SELECT dropIfExists('FUNCTION', 'getFreightTaxSelection(INTEGER)');
SELECT dropIfExists('FUNCTION', 'changeInvoiceTaxAuth(INTEGER, INTEGER)');
SELECT dropIfExists('FUNCTION', 'changeCobTaxAuth(INTEGER, INTEGER)');
SELECT dropIfExists('FUNCTION', 'getTaxSelection(INTEGER, INTEGER)');
SELECT dropIfExists('FUNCTION', 'calculatetax(integer, numeric, numeric, bpchar)');
SELECT dropIfExists('FUNCTION', 'calculatetax(integer, numeric, numeric)');

COMMIT;
