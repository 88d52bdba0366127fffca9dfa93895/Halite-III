const path = require("path");

// https://github.com/vuejs-templates/webpack-simple
module.exports = {
    entry: ['babel-polyfill', './javascript/main.js'],
    output: {
        path: path.resolve(__dirname, "assets/js/"),
        filename: "bundle.js",
    },
    module: {
        noParse: /libzstd/,
        rules: [
            {
                test: /\.js$/,
                exclude: /(node_modules|libzstd)/,
                use: {
                    loader: 'babel-loader',
                    options: {
                        presets: [
                            ['env', {
                                targets: {
                                    browsers: ["last 2 versions", "safari >= 7"]
                                }
                            }],
                        ],
                        env: {
                            "production": {
                                // TODO: figure out why we can't enable babili here
                                // "presets": ["babili"]
                            }
                        },
                    }
                }
            },
            {
                test: /\.vue$/,
                loader: 'vue-loader',
                options: {
                    loaders: {
                        'scss': 'vue-style-loader!css-loader!sass-loader',
                        'sass': 'vue-style-loader!css-loader!sass-loader?indentedSyntax',
                        'js': {
                            loader: 'babel-loader',
                            options: {
                                presets: [
                                    ['env', {
                                        targets: {
                                            browsers: ["last 2 versions", "safari >= 7"]
                                        }
                                    }],
                                ],
                                env: {
                                    "production": {
                                        // TODO: figure out why we can't enable babili here
                                        // "presets": ["babili"]
                                    }
                                },
                            }
                        }
                    }
                }
            },
            {
                test: /\.css$/,
                loader: 'style-loader!css-loader'
            },
            // Work around pixi-extra-filter's use of glslify (which is
            // browserify-dependent) to load shaders
            {
                test: path.resolve(__dirname, "node_modules", "pixi-extra-filters"),
                loader: "ify-loader",
            },
            {
                test: /pixi-extra-filters/,
                loader: "ify-loader",
            },
            {
                test: /\.(png|ttf|woff)$/,
                loader: "file-loader",
            },
        ],
    },
    resolve: {
        alias: {
            'vue$': 'vue/dist/vue.esm.js'
        }
    },
};

