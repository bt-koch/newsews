import plotly.graph_objects as go

class interactive:

    def linechart(dataframe):

        bank = dataframe["bank"].unique()

        if len(bank) != 1:
            print("Multiple banks (or none) in dataset. Only accepts dataframe with single bank.")
            return None

        fig = go.Figure()

        fig.add_trace(go.Scatter(
            x=dataframe["date"],
            y=dataframe["sentiment_score"],
            mode="lines",
            name="Sentiment Score",
            line=dict(color="lightgrey")
        ))

        fig.add_trace(go.Scatter(
            x=dataframe["date"],
            y=dataframe["moving_average"],
            mode="lines",
            name="Rolling MA",
            line=dict(color="red")
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