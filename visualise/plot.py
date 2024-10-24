import plotly.graph_objects as go
import random

class interactive:

    def linechart(dataframe, x_value="date", y_value="sentiment_score"):

        bank = dataframe["bank"].unique()

        if len(bank) != 1:
            print("Multiple banks (or none) in dataset. Only accepts dataframe with single bank.")
            return None

        fig = go.Figure()

        if type(y_value) is str:
            fig.add_trace(go.Scatter(
                x=dataframe[x_value],
                y=dataframe[y_value],
                mode="lines",
                name=y_value,
                line=dict(color="lightgrey")
            ))
        elif type(y_value) is list:
            for y_dim in y_value:
                fig.add_trace(go.Scatter(
                    x=dataframe[x_value],
                    y=dataframe[y_dim],
                    mode="lines",
                    name=y_dim,
                    line=dict(color="#{:06x}".format(random.randint(0, 0xFFFFFF)))
                ))

        fig.update_layout(
            title="Sentiment Scores of "+bank[0]+" Articles (red: rolling MA)",
            xaxis_title="Date",
            yaxis_title="Sentiment Score [-1, 1]",
            xaxis_tickangle=-45,
            height=600,
            width=1400,
            plot_bgcolor="#F5F5F5"
        )

        fig.show()