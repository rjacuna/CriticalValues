const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
(async () => {
 const source = fs.readFileSync(path.join(__dirname, '../web/js/parse.js'));
 const {toWire} = await import('data:text/javascript;base64,' + source.toString('base64'));
 for (const [input, wire] of [
  ['x^2-3', '(- (^ x 2) 3)'],
  ['-x^2', '(- (^ x 2))'],
  ['(-x)^2', '(^ (- x) 2)'],
  ['x^2^3', '(^ x (^ 2 3))'],
  ['2x(x+1)', '(* (* 2 x) (+ x 1))'],
  ['(x+1)(x-1)', '(* (+ x 1) (- x 1))'],
  ['2/3x', '(* (/ 2 3) x)'],
  ['x/2x', '(/ x (* 2 x))'],
  ['x/2+1', '(+ (/ x 2) 1)'],
  ['0.5x+1', '(+ (* (/ 5 10) x) 1)'],
  ['1e-3x+1', '(+ (* (/ 1 1000) x) 1)'],
  ['9007199254740993x+1', '(+ (* 9007199254740993 x) 1)'],
  ['t^3-2', '(- (^ x 3) 2)'],
  ['-2, 0, +1', '-2,0,+1'],
 ]) assert.equal(toWire(input), wire, input);
 for (const input of ['', 'x+y', 'x^', '(x+1', 'x+1)', 'x;alert(1)', '1,,2', '1e999999999x'])
  assert.throws(() => toWire(input), undefined, input);
 console.log('Bundled parser: precedence, implicit products, exact literals, alternate variable and invalid input PASS');
})().catch(error => {console.error(error);process.exitCode = 1;});
