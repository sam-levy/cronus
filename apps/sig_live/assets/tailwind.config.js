module.exports = {
  mode: "jit",
  purge: ["./js/**/*.js", "../lib/*_live/**/*.*ex"],
  content: [
    "../lib/sig_live/**/*.heex",
    "../lib/sig_live/**/*.ex"
  ],
  theme: {
    extend: {},
  },
  variants: {
    extend: {
      backgroundColor: ['odd'],
    },
  },
  plugins: [require('@tailwindcss/forms')],
};
